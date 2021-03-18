app = Proc.new do |env|
    ["200", {
        "Content-Type" => "text/plain",
    }, ["Hello, Ruby on Unit!\n"]]
end

run app
