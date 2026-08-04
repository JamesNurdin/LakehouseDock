WITH item_daily AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS store_sales_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_returns_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        MAX(cs.cs_ext_wholesale_cost) AS max_catalog_wholesale_cost
    FROM store_sales ss
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    RIGHT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_units IN ('Bunch', 'Carton')
      AND r.r_reason_desc LIKE '%defect%'
      AND cp.cp_catalog_number > 10
      AND sr.sr_return_amt > 100
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    item_id,
    year,
    store_sales_amount,
    store_returns_amount,
    (store_sales_amount - store_returns_amount) AS net_amount,
    max_catalog_wholesale_cost,
    ROW_NUMBER() OVER (ORDER BY (store_sales_amount - store_returns_amount) DESC) AS rn
FROM item_daily
WHERE (store_sales_amount - store_returns_amount) > (
    SELECT AVG(store_sales_amount - store_returns_amount)
    FROM item_daily
)
ORDER BY net_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
