import type { Schema, Attribute } from '@strapi/strapi';

export interface ProjectsTestimonial extends Schema.Component {
  collectionName: 'components_projects_testimonials';
  info: {
    displayName: 'Testimonial';
    description: '';
  };
  attributes: {
    founder: Attribute.String & Attribute.Required;
    testimonial: Attribute.Text & Attribute.Required;
    clientDesignation: Attribute.String & Attribute.Required;
  };
}

declare module '@strapi/types' {
  export module Shared {
    export interface Components {
      'projects.testimonial': ProjectsTestimonial;
    }
  }
}
