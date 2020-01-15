"use strict";

class Entity {
	
	constructor(location, maxSpeed, mass, shape) {

		this.location = location || new Vector();
		this.velocity = new Vector();
		this.acceleration = new Vector();
		this.shape = shape || {};
		
		this.mass = mass || 0.0;
		this.maxSpeed = maxSpeed || 0.0;
		this.collision = 0;

		this.angle = 0;
		this.angleVelocity = 0;
		this.angleAcceleration = 0;

		return Object.seal(this);
	}
}