WITH agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        i.i_size AS size,
        hd.hd_income_band_sk AS income_band,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
      AND i.i_size IN ('medium', 'large')
      AND ws.ws_ext_wholesale_cost > 500
      AND hd.hd_dep_count <= 2
      AND hd.hd_income_band_sk IN (3, 10, 12)
    GROUP BY i.i_item_id, i.i_item_desc, i.i_size, hd.hd_income_band_sk
)
SELECT
    item_id,
    item_desc,
    size,
    income_band,
    total_profit,
    total_qty,
    RANK() OVER (PARTITION BY income_band ORDER BY total_profit DESC) AS profit_rank,
    CASE
        WHEN total_profit >= 100000 THEN 'High'
        WHEN total_profit >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM agg
ORDER BY income_band, profit_rank
LIMIT 100
