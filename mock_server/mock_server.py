from flask import Flask, request, jsonify

app = Flask(__name__)

tasks = []

@app.route("/tasks", methods=["GET"])
def get_tasks():
    return jsonify(tasks)

@app.route("/tasks", methods=["POST"])
def post_task():
    task = request.json
    for i, t in enumerate(tasks):
        if t["id"] == task["id"]:
            tasks[i] = task
            break
    else:
        tasks.append(task)
    return jsonify({"status": "ok"})

@app.route("/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    global tasks
    tasks = [t for t in tasks if t["id"] != task_id]
    return jsonify({"status": "deleted"})

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
