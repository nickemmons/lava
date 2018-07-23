# Lava
> Decentralized Random Number Generation

### _\*\*\*OFFICIAL WHITE PAPER AND MORE TO COME - STAY TUNED!\*\*\*_

## Technical Summary

1. Rand submitters (randers = rands) send their Rand and deposit, Prediction submitters (preders = preds) send their Prediction and 1 deposit per prediction
2. Rands get their deposit whence there does not exist a prediction window governing their prediction and no pred successessfully predicted that their rand would chosen upon request
   Preds get their deposit back when they successfully predict the next rand to be sent out of network whenever new one is requested OR when a pred of larger window size is proposed (so that rands can't prevent genuine audits by floodding the system with preds of increasingly longer window property - it would become increasingly expensive to submit, and whenever preds with windows that are too long are submitted, then a new contarct is simply created and people move to that)
   Otherwise, preds lose deposity per guess that's wrong within their window
3. The first rand to be sent whence the network receives a request with an ETH amount R is the selected rand (that is subject to the pred's auditing)
4. "Prediction Window Space Unit" goes to highest bidder > size of window for which prediction unit belongs > earliest time of submission
5. Submitted rands constitute a large, unidirectional, cyclical array.

## Why It Works

Read these:

* https://stats.stackexchange.com/questions/66108/why-is-entropy-maximised-when-the-probability-distribution-is-uniform

* https://math.stackexchange.com/questions/275652/equivalence-between-uniform-and-normal-distribution

* https://en.wikipedia.org/wiki/Maximum_entropy_probability_distribution#Uniform_and_piecewise_uniform_distributions

* https://math.stackexchange.com/questions/1156404/entropy-of-a-uniform-distribution

## Contributors

Kenny Peluso

## License

MIT

