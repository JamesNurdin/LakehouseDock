WITH store_ret AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        'Store' AS return_type,
        sr.sr_net_loss AS net_loss,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_item_sk = sr.sr_item_sk
            AND cs.cs_order_number = sr.sr_ticket_number
      )
),
web_ret AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        'Web' AS return_type,
        wr.wr_net_loss AS net_loss,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_item_sk = wr.wr_item_sk
            AND cs.cs_order_number = wr.wr_order_number
      )
)
SELECT
    u.item_sk,
    u.return_type,
    SUM(u.net_loss) AS total_net_loss,
    CASE
        WHEN u.hd_buy_potential LIKE '>%' THEN 'High'
        WHEN u.hd_buy_potential = '5001-10000' THEN 'Medium'
        ELSE 'Low'
    END AS buy_potential_category,
    CASE
        WHEN u.hd_income_band_sk > (SELECT AVG(hd_income_band_sk) FROM household_demographics) THEN 'AboveAvg'
        ELSE 'BelowAvg'
    END AS income_band_category
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
) u
GROUP BY
    u.item_sk,
    u.return_type,
    u.hd_buy_potential,
    u.hd_income_band_sk
ORDER BY
    total_net_loss DESC
LIMIT 100
