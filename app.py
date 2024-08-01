from flask import Flask, redirect, url_for
import hashlib
def hash_id(user_id):
    return hashlib.sha256(str(user_id).encode()).hexdigest()

def decrypt_id(hashed_id):
    # Simplified decryption for demonstration purposes
    # In a real-world scenario, you would use a proper encryption/decryption method
    return hashed_id

app = Flask(__name__)

@app.route('/')
def hello_world():
    user_id = 1  # Example user ID
    hashed_user_id = hash_id(user_id)
    return f'<h1>Hello, World!</h1> <a href="{url_for("user_page", hashed_id=hashed_user_id)}">View User</a>'

@app.route('/user/<hashed_id>')
def user_page(hashed_id):
    user_id = decrypt_id(hashed_id)
    return f'<h1>User Page</h1> <p>User ID: {user_id}</p>'

if __name__ == '__main__':
    app.run(debug=True)
