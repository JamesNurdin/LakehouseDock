WITH union_data AS (
    -- Returns with higher fees
    SELECT
        d.d_year,
        i.i_category,
        hd.hd_buy_potential,
        sr.sr_return_amt_inc_tax,
        inv.inv_quantity_on_hand
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    JOIN inventory inv2 ON inv2.inv_item_sk = i.i_item_sk
                         AND inv2.inv_date_sk = d_start.d_date_sk
    WHERE sr.sr_fee > 30

    UNION ALL

    -- Returns with lower or equal fees
    SELECT
        d.d_year,
        i.i_category,
        hd.hd_buy_potential,
        sr.sr_return_amt_inc_tax,
        inv.inv_quantity_on_hand
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    JOIN inventory inv2 ON inv2.inv_item_sk = i.i_item_sk
                         AND inv2.inv_date_sk = d_start.d_date_sk
    WHERE sr.sr_fee <= 30
)
SELECT
    d_year,
    i_category,
    hd_buy_potential,
    SUM(sr_return_amt_inc_tax) AS total_return_amt,
    SUM(inv_quantity_on_hand)   AS total_inventory_qty,
    CASE WHEN SUM(sr_return_amt_inc_tax) > 10000 THEN 'High' ELSE 'Low' END AS return_level,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank,
    SUM(SUM(sr_return_amt_inc_tax)) OVER (
        PARTITION BY d_year
        ORDER BY i_category
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_return_by_category
FROM union_data
GROUP BY d_year, i_category, hd_buy_potential
ORDER BY total_return_amt DESC
LIMIT 100
