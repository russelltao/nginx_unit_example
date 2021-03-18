package main

import (
    "io";
    "net/http";
    "unit.nginx.org/go"
)

func main() {
    http.HandleFunc("/",func (w http.ResponseWriter, r *http.Request) {
        io.WriteString(w, "Hello, Go on Unit!\n")
    })
    unit.ListenAndServe(":8080", nil)
}
