WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_cdemo_sk,
        SUM(ss_quantity) AS total_qty_sold,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_net_paid > 0
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_cdemo_sk
),
returns_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        sr_cdemo_sk,
        SUM(sr_return_quantity) AS return_qty,
        SUM(sr_return_amt) AS return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_cdemo_sk
),
cat_union AS (
    SELECT DISTINCT i_category
    FROM item
    WHERE i_color = 'turquoise'
    UNION
    SELECT DISTINCT i_category
    FROM item
    WHERE i_units = 'Carton'
)
SELECT
    i.i_brand,
    d.d_year,
    cp.cp_catalog_page_id,
    ws.web_name,
    cd.cd_gender,
    SUM(s.total_qty_sold) AS total_quantity_sold,
    SUM(s.total_sales) AS total_sales_amount,
    SUM(s.total_profit) AS total_profit_before_returns,
    SUM(COALESCE(r.return_qty, 0)) AS total_return_quantity,
    SUM(COALESCE(r.return_amt, 0)) AS total_return_amount,
    SUM(s.total_profit - COALESCE(r.return_amt, 0)) AS net_profit_after_returns,
    (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2001) AS max_date_2001
FROM sales_agg s
JOIN item i
    ON s.ss_item_sk = i.i_item_sk
JOIN date_dim d
    ON s.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON s.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg r
    ON r.sr_item_sk = s.ss_item_sk
   AND r.sr_returned_date_sk = d.d_date_sk
   AND r.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_color IN ('turquoise', 'sienna')
  AND i.i_units = 'Pound'
  AND cd.cd_gender = 'M'
  AND ws.web_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_quantity > 0
    )
  AND i.i_category IN (SELECT i_category FROM cat_union)
GROUP BY i.i_brand, d.d_year, cp.cp_catalog_page_id, ws.web_name, cd.cd_gender
HAVING SUM(s.total_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
