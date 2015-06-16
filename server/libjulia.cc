#include <libjulia.h>
#include <Magick++.h>

#include <v8.h>
#include <node.h>
#include <node_buffer.h>

#include <vector>
#include <thread>
#include <cstdlib>
#include <cstring>
#include <algorithm>

using namespace std;
using namespace v8;
using namespace Magick;

const int threads_cnt = 4; // TODO : make it function argument

struct JuliaBaton {
    uv_work_t request;
    Persistent<Function> callback;
    JuliaPart * info;
    int32_t x1, y1, x2, y2;
    char filename[24];
};

void parallelDraw(JuliaPart * info, uint32_t * out, uint32_t y, int32_t x1, int32_t y1, int32_t x2, int32_t y2) {
    juliaGeneratePart(info, out + ((uint64_t) (x2 - x1)) * (y1 - y), x1, y1, x2, y2);
}

static void generatePartAsync(uv_work_t * req) {
    JuliaBaton * b = static_cast<JuliaBaton *>(req->data);

    // Create julia image
    uint32_t * pixels = new uint32_t[(b->x2 - b->x1) * (b->y2 - b->y1)];

    // Draw it using multiple threads
    vector<thread> threads;
    int32_t dh = (b->y2 - b->y1 + threads_cnt - 1) / threads_cnt;
    int32_t y_1 = b->y1, y_2 = b->y1 + dh;
    for (int i = 0; i < threads_cnt; i++) {
        threads.push_back(thread(parallelDraw, b->info, pixels, b->y1, b->x1, y_1, b->x2, y_2));
        y_1 += dh;
        y_2 = min(y_2 + dh, b->y2);
    }

    // Wait for all threads to terminate
    for (auto & t : threads) {
        t.join();
    }

    // Output to temporary file
    char filename[] = "/tmp/juliaXXXXXX";
    mktemp(filename);
    memcpy(b->filename, filename, 17);

    Image image(b->x2 - b->x1, b->y2 - b->y1, "BGRP", CharPixel, pixels);
    image.magick("PNG");
    image.write(filename);

    // Do the cleanup
    delete b->info;
    delete pixels;
}

static void generatePartAfter(uv_work_t * req, int status) {
    JuliaBaton * baton = static_cast<JuliaBaton *>(req->data);

    // Callback with temporary image path
    Handle<Value> argv[1] = {String::New(baton->filename)};

    baton->callback->Call(Context::GetCurrent()->Global(), 1, argv);
    baton->callback.Dispose();

    delete baton;
}

// generatePart(a, b, scale, maxn, x1, y1, x2, y2, callback) -> callback(filename)
Handle<Value> generatePart(const Arguments & args) {

    // Parse args
    float a = (float) args[0]->NumberValue();
    float b = (float) args[1]->NumberValue();
    float scale = (float) args[2]->NumberValue();
    uint32_t maxn = args[3]->Uint32Value();
    int32_t x1 = args[4]->Int32Value();
    int32_t y1 = args[5]->Int32Value();
    int32_t x2 = args[6]->Int32Value();
    int32_t y2 = args[7]->Int32Value();
    Handle<Function> callback = Handle<Function>::Cast(args[8]);

    // Create julia part description
    JuliaPart * info = new JuliaPart;
    info->a = a;
    info->b = b;
    info->scale = scale;
    info->maxn = maxn;

    // Create baton for delayed julia execution
    JuliaBaton * baton = new JuliaBaton;
    baton->request.data = baton;
    baton->callback = Persistent<Function>::New(callback);
    baton->info = info;
    baton->x1 = x1;
    baton->y1 = y1;
    baton->x2 = x2;
    baton->y2 = y2;

    // Queue the async function to the event loop
    uv_queue_work(uv_default_loop(), &baton->request, generatePartAsync, generatePartAfter);
    
    return Undefined();
}

void init(Handle<Object> target) {
    target->Set(String::NewSymbol("generatePart"), FunctionTemplate::New(generatePart)->GetFunction());
}

NODE_MODULE(julia, init);
