import React, { Component } from 'react';
import Iframe from 'react-iframe';

export default class ViewSlot extends Component {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <div>
        <div className="head">
          <div className="title">Slot Machine</div>
          <Iframe url="http://localhost:3000/slot-machine/" 
            width="100%"
            height="1920"
            id="myId"
            className="myClassname"
            display="initial"
            position="relative"
            allowFullScreen
          />
        </div>
      </div>
    )
  } 
} 