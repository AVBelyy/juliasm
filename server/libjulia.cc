#include <libjulia.h>
#include <Magick++.h>

#include <v8.h>
#include <node.h>
#include <node_buffer.h>

#include <vector>
#include <thread>
#include <cstdlib>
#include <algorithm>

using namespace std;
using namespace v8;
using namespace Magick;

const int threads_cnt = 4; // TODO : make it function argument

void parallelDraw(JuliaPart * info, uint32_t * out, uint32_t y, uint32_t x1, uint32_t y1, uint32_t x2, uint32_t y2) {
    juliaGeneratePart(info, out + ((uint64_t) (x2 - x1)) * (y1 - y), x1, y1, x2, y2);
}

// TODO : make it truly async
// generatePart(w, h, a, b, scale, x1, y1, x2, y2, callback) -> callback(filename)
Handle<Value> generatePart(const Arguments & args) {
    HandleScope scope;

    // Parse args
    uint32_t w = args[0]->Uint32Value();
    uint32_t h = args[1]->Uint32Value();
    float a = (float) args[2]->NumberValue();
    float b = (float) args[3]->NumberValue();
    float scale = (float) args[4]->NumberValue();
    uint32_t x1 = args[5]->Uint32Value();
    uint32_t y1 = args[6]->Uint32Value();
    uint32_t x2 = args[7]->Uint32Value();
    uint32_t y2 = args[8]->Uint32Value();
    Local<Function> callback = Local<Function>::Cast(args[9]);

    // Create julia image
    JuliaPart info = {w, h, a, b, scale};
    uint32_t * pixels = new uint32_t[(x2 - x1) * (y2 - y1)];

    // Draw it using multiple threads
    vector<thread> threads;
    uint32_t dh = (y2 - y1 + threads_cnt - 1) / threads_cnt;
    uint32_t y_1 = y1, y_2 = y1 + dh;
    for (int i = 0; i < threads_cnt; i++) {
        threads.push_back(thread(parallelDraw, &info, pixels, y1, x1, y_1, x2, y_2));
        y_1 += dh;
        y_2 = min(y_2 + dh, y2);
    }
    for (auto & t : threads) {
        t.join();
    }

    // Output to temporary file
    char filename[] = "/tmp/juliaXXXXXX";
    mktemp(filename);

    Image image(x2 - x1, y2 - y1, "BGRP", CharPixel, pixels);
    image.magick("PNG");
    image.write(filename);

    // Do the cleanup
    delete pixels;

    // Callback with temporary image path
    Handle<Value> argv[1] = {String::New(filename)};

    callback->Call(Context::GetCurrent()->Global(), 1, argv);
    
    return scope.Close(Undefined());
}

void init(Handle<Object> target) {
    target->Set(String::NewSymbol("generatePart"), FunctionTemplate::New(generatePart)->GetFunction());
}

NODE_MODULE(julia, init);
