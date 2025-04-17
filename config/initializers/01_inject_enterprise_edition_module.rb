# frozen_string_literal: true

# original Authors: Gitlab
# https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/0_inject_enterprise_edition_module.rb
#

### Ref: https://medium.com/@leo_hetsch/ruby-modules-include-vs-prepend-vs-extend-f09837a5b073
# Ancestors chain : it holds a list of constant names which are its ancestors
#  example, by calling ancestors on the String class,
#  String.ancestors => [String, Comparable, Object, PP::ObjectMixin, Kernel, BasicObject]
#
# Include: Ruby will insert the module into the ancestors chain of the class, just after its superclass
# ancestor chain : [OriginalClass, IncludedModule, ...]
#
# Extend: class will actually import the module methods as class methods
#
# Prepend: Ruby will look into the module methods before looking into the class.
# ancestor chain : [PrependedModule, OriginalClass, ...]
########

require 'active_support/inflector'

module InjectEnterpriseEditionModule
  def prepend_mod_with(constant_name, namespace: Object, with_descendants: false)
    Rails.logger.info "Attempting to prepend module for #{constant_name}"
    each_extension_for(constant_name, namespace) do |constant|
      begin
        prepend_module(constant, with_descendants)
        Rails.logger.info "Successfully prepended module for #{constant_name}"
      rescue => e
        Rails.logger.error "Failed to prepend module for #{constant_name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  def extend_mod_with(constant_name, namespace: Object)
    Rails.logger.info "Attempting to extend module for #{constant_name}"
    begin
      each_extension_for(constant_name, namespace) do |constant|
        extend(constant)
        Rails.logger.info "Successfully extended module for #{constant_name}"
      end
    rescue => e
      Rails.logger.error "Failed to extend module for #{constant_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def include_mod_with(constant_name, namespace: Object)
    Rails.logger.info "Attempting to include module for #{constant_name}"
    begin
      each_extension_for(constant_name, namespace) do |constant|
        include(constant)
        Rails.logger.info "Successfully included module for #{constant_name}"
      end
    rescue => e
      Rails.logger.error "Failed to include module for #{constant_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def prepend_mod(with_descendants: false)
    prepend_mod_with(name, with_descendants: with_descendants)
  end

  def extend_mod
    extend_mod_with(name)
  end

  def include_mod
    include_mod_with(name)
  end

  private

  def prepend_module(mod, with_descendants)
    prepend(mod)

    descendants.each { |descendant| descendant.prepend(mod) } if with_descendants
  end

  def each_extension_for(constant_name, namespace)
    return unless ChatwootApp.respond_to?(:extensions)
    
    Rails.logger.info "Loading extensions for #{constant_name}"
    ChatwootApp.extensions.each do |extension_name|
      begin
        Rails.logger.info "Processing extension: #{extension_name}"
        extension_namespace = const_get_maybe_false(namespace, extension_name.camelize)
        next unless extension_namespace

        Rails.logger.info "Found namespace for #{extension_name}: #{extension_namespace}"
        extension_module = const_get_maybe_false(extension_namespace, constant_name)
        next unless extension_module

        Rails.logger.info "Found module for #{constant_name} in #{extension_name}"
        yield(extension_module)
      rescue => e
        Rails.logger.error "Error processing extension #{extension_name}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  def const_get_maybe_false(mod, name)
    return false unless mod
    return false unless mod.const_defined?(name, false)
    
    begin
      mod.const_get(name, false)
    rescue => e
      Rails.logger.error "Error getting constant #{name} from #{mod}: #{e.message}"
      false
    end
  end
end

begin
  Module.prepend(InjectEnterpriseEditionModule)
  Rails.logger.info "Successfully prepended InjectEnterpriseEditionModule"
rescue => e
  Rails.logger.error "Failed to prepend InjectEnterpriseEditionModule: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
end
