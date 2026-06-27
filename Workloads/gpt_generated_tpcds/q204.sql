/*
  Analytical query: Return performance by hour, shift, and meal time.
  It aggregates return amounts, quantities, taxes, fees, shipping costs, refunds, store credits, and net loss.
  It also calculates average net loss per returned item and a profit‑margin‑like metric.
*/
WITH filtered_returns AS (
    SELECT
        cr_returned_time_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_store_credit,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 0
)
SELECT
    td.t_hour,
    td.t_shift,
    td.t_meal_time,
    COUNT(*) AS return_count,
    SUM(fr.cr_return_quantity) AS total_return_quantity,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_return_tax) AS total_return_tax,
    SUM(fr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(fr.cr_fee) AS total_fee,
    SUM(fr.cr_return_ship_cost) AS total_ship_cost,
    SUM(fr.cr_refunded_cash) AS total_refunded_cash,
    SUM(fr.cr_store_credit) AS total_store_credit,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    AVG(fr.cr_net_loss) AS avg_net_loss,
    SUM(fr.cr_net_loss) / NULLIF(SUM(fr.cr_return_quantity), 0) AS avg_net_loss_per_return,
    (SUM(fr.cr_return_amt_inc_tax) - SUM(fr.cr_fee) - SUM(fr.cr_return_ship_cost) - SUM(fr.cr_refunded_cash) - SUM(fr.cr_store_credit))
        / NULLIF(SUM(fr.cr_return_amt_inc_tax), 0) AS profit_margin
FROM filtered_returns fr
JOIN time_dim td
    ON fr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_shift IN ('Morning', 'Afternoon', 'Evening')
GROUP BY td.t_hour, td.t_shift, td.t_meal_time
ORDER BY total_return_amount_inc_tax DESC
LIMIT 100
