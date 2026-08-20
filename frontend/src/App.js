import React, { useState, useEffect } from 'react';

function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState('');
  const [views, setViews] = useState(0);

  const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

  const fetchTasks = () => {
    fetch(`${API_URL}/tasks`)
      .then(res => res.json())
      .then(data => {
        if (data.tasks) setTasks(data.tasks);
        if (data.views_counter) setViews(data.views_counter);
      })
      .catch(err => console.error(err));
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const addTask = (e) => {
    e.preventDefault();
    fetch(`${API_URL}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title }),
    }).then(() => {
      setTitle('');
      fetchTasks();
    });
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial' }}>
      <h1>DevOps Task & Analytics Engine</h1>
      <p>Page Analytics (Redis Views Counter): <strong>{views}</strong></p>
      
      <form onSubmit={addTask}>
        <input 
          value={title} 
          onChange={(e) => setTitle(e.target.value)} 
          placeholder="Novi task..." 
          required 
        />
        <button type="submit">Dodaj Task</button>
      </form>

      <ul>
        {tasks.map((t, idx) => (
          <li key={idx}>{t[1]}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;