package com.mattc2pa.app;

public final class ManifestServiceFactory {

    // Fields

    private boolean finished = false;
    private ManifestService manifestService = null;
    
    // Constructors

    public ManifestServiceFactory() {
        setService(new ManifestService());
    }

    // Methods

    public ManifestServiceFactory withLogging() {
        checkFinished();
        return this;
    }

    public ManifestService finish() {
        setFinished(true);
        return getService();
    }

    private void checkFinished() {
        if (isFinished()) {
            throw new IllegalStateException("Factory has already been finished");
        }
    }

    // Getters and Setters

    private void setService(final ManifestService manifestService) {
        this.manifestService = manifestService;
    }

    private ManifestService getService() {
        return manifestService;
    }

    private void setFinished(final boolean finished) {
        this.finished = finished;
    }

    public boolean isFinished() {
        return finished;
    }
}