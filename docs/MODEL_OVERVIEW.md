# Model overview

The model represents cultural accumulation as search over structured behavioural sequences. Each agent carries a sequence of `D = 10` discrete components drawn from an alphabet of size `A = 5`. The target sequence is the all-ones sequence; the repeated numerical label is a coding convention rather than a substantive behavioural assumption.

## Cultural update cycle

Population updates are synchronous. During each cultural update round, every learner evaluates demonstrators and its current state from an immutable copy of the population at the start of the round. Accepted variants become visible to other agents only in the next round.

Within an individual update, the order is:

1. retain the current behaviour as the starting candidate;
2. optionally sample and copy a demonstrator;
3. optionally innovate one sequence component;
4. evaluate the resulting candidate under the task-specific payoff;
5. accept or reject the candidate relative to the learner's current behaviour;
6. write accepted changes to the next-round population.

This ordering separates access, transmission, innovation, evaluation, and retention.

## Task structures

Let `m(x)` be the fraction of components matching the target.

### Smooth

Every correct component contributes independently:

`q_smooth(x) = m(x)`.

### Opaque

Partial correctness is compressed by a nonlinear payoff mapping:

`q_opaque(x) = (1-lambda)m(x) + lambda m(x)^p`,

with baseline `lambda = 0.90` and `p = 8`.

### Strict sequence

Only the longest correct prefix contributes. If `L(x)` is the longest correct prefix,

`q_strict(x) = (L(x)/D)^s`,

with baseline `s = 2`.

The behavioural state space is identical across task structures; only the mapping from behavioural structure to payoff differs.

## Social learning and innovation

An agent attempts social learning with probability `P_social = 0.80`. It samples `k = 5` potential demonstrators and selects among them with a success bias controlled by `beta`. Copying occurs component-wise with fidelity `phi`, modified by scaffolding `tau` as

`phi_eff = phi + tau(1-phi)`.

In the baseline loss-only transmission model, copying error cannot accidentally convert an incorrect component into the target value. The repair-capable-error control deliberately relaxes this assumption so that transmission noise can also generate improvements.

Innovation occurs with probability `mu` and changes one randomly chosen sequence position to a different action without information about whether the change is beneficial.

## Evaluation and retention

Candidate acceptance follows a logistic comparison of candidate and current payoff,

`P(accept) = 1 / (1 + exp[-gamma(q_candidate - q_current)])`.

The baseline uses `gamma = 10`. The greedy-acceptance control accepts candidates if and only if they are not worse. The discrimination-sensitivity analysis varies both success bias (`beta`) and evaluation strength (`gamma`).

## Cultural ancestry

Every accepted changed sequence is stored as a new cultural variant linked to its parent. Two lineage measures are used:

- **functional lineage depth**: increments when a descendant improves task-specific payoff relative to its cultural parent;
- **structural lineage depth**: increments when a descendant improves target-component accuracy relative to its parent.

Structural lineage depth is an analyst-side diagnostic; it is not an additional signal available to agents during learning.

## Scope

The model addresses bounded accumulation toward a fixed target in a fixed behavioural state space. It is not a model of open-ended cultural evolution, multiple adaptive optima, or species-specific cognition.
