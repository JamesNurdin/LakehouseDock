/*
Goal: Identify high‑price items that generated the largest return amounts, filtered by promotion channel (direct mail), returning customer time zone, and household income band, and rank them by total return amount and quantity.
*/
WITH filtered_returns AS (
    SELECT
        w.wr_item_sk,
        w.wr_return_quantity,
        w.wr_return_amt,
        w.wr_net_loss,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        p.p_promo_name,
        p.p_channel_dmail,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        ca_ret.ca_gmt_offset AS returning_gmt_offset
    FROM web_returns w
    JOIN item i ON w.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd_ref ON w.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON w.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ref ON w.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON w.wr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE i.i_current_price > 20.00
      AND p.p_channel_dmail = 'Y'
      AND ca_ret.ca_gmt_offset = -5.00
      AND hd_ref.hd_income_band_sk IN (12, 17)
      AND w.wr_return_quantity >= 2
)
SELECT
    fr.i_item_id,
    fr.i_product_name,
    fr.p_promo_name,
    SUM(fr.wr_return_amt)               AS total_return_amount,
    SUM(fr.wr_return_quantity)          AS total_return_quantity,
    SUM(fr.wr_net_loss)                 AS total_net_loss,
    CASE
        WHEN SUM(fr.wr_net_loss) > 1000 THEN 'High Loss'
        ELSE 'Moderate Loss'
    END                                 AS loss_category,
    RANK() OVER (ORDER BY SUM(fr.wr_return_amt) DESC)                                   AS return_amount_rank,
    DENSE_RANK() OVER (PARTITION BY fr.p_channel_dmail ORDER BY SUM(fr.wr_return_quantity) DESC) AS quantity_dense_rank
FROM filtered_returns fr
GROUP BY
    fr.i_item_id,
    fr.i_product_name,
    fr.p_promo_name,
    fr.p_channel_dmail
ORDER BY total_return_amount DESC
LIMIT 100
