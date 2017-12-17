import React, { Component } from 'react';
import {
    BrowserRouter as Router,
    Route,Redirect,
    NavLink
} from 'react-router-dom';

import ViewMain from './ViewMain';
import ViewSlot from './ViewSlot';

class App extends Component {
  constructor(props) {
    super(props);
  }
  
  render() {
    return (
      <Router>
        <div>
          <Route path="/main" component={ViewMain} />
          <Route path="/slot" component={ViewSlot} />
          <ul>
            <li>
              <NavLink to="/main">Main</NavLink>
            </li>
            <li>
              <NavLink to="/slot">slot</NavLink>
            </li>          
          </ul>
        </div>
      </Router>
    )
  }
}
export default App;