"use strict";

class Vector {

	constructor(x, y) {
		this.x = x || 0.0;
		this.y = y || 0.0;

		return Object.seal(this);
	}

	// INSTANCE
	add(vector) {
		this.x = this.x + vector.x;
		this.y = this.y + vector.y;
		return this;
	}

	sub(vector) {
		this.x = this.x - vector.x;
		this.y = this.y - vector.y;
		return this;
	}

	mult(scalar) {
		this.x = this.x * scalar;
		this.y = this.y * scalar;
		return this;
	}

	div(scalar) {
		this.x = this.x / scalar;
		this.y = this.y / scalar;
		return this;
	}

	mag() {
		return Math.sqrt(this.x * this.x + this.y * this.y);
	}

	normalize() {
		let mag = this.mag();
		if (mag > 0) this.div(mag);
		return this;
	}

	limit(max) {
		if (this.mag() > max) this.setMag(max);
		return this;
	}

	setMag(magnitude) {
		let ourMag = this.mag();
		this.x = this.x * (magnitude / ourMag);
		this.y = this.y * (magnitude / ourMag);
		return this;
	}

	copy() {
		return new Vector(this.x, this.y);
	}

	heading() { // Radians
		return Math.atan2(this.y, this.x);
	}

	headingDegrees() {
		return this.heading() * (180 / Math.PI);
	}

	rotate(radians) {
		this.x = this.x * Math.cos(radians) - this.y * Math.sin(radians);
		this.y = this.x * Math.sin(radians) - this.y * Math.cos(radians);
	}

	// STATIC
	static add(vector1, vector2) {
		return new Vector(vector1.x + vector2.x, vector1.y + vector2.y);
	}

	static sub(vector1, vector2) {
		return new Vector(vector1.x - vector2.x, vector1.y - vector2.y);
	}

	static mult(vector, scalar) {
		return new Vector(vector.x * scalar, vector.y * scalar);
	}

	static div(vector, scalar) {
		return new Vector(vector.x / scalar, vector.y / scalar);
	}
}