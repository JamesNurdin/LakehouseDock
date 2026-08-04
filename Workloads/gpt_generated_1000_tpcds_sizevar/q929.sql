WITH
    cust_store AS (
        SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
          AND sr.sr_return_amt > 500
    ),
    cust_web AS (
        SELECT DISTINCT wr.wr_refunded_customer_sk AS c_customer_sk
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
          AND wr.wr_return_amt > 500
    ),
    cust_common AS (
        SELECT c_customer_sk FROM cust_store
        INTERSECT
        SELECT c_customer_sk FROM cust_web
    ),
    cust_only_store AS (
        SELECT c_customer_sk FROM cust_store
        EXCEPT
        SELECT c_customer_sk FROM cust_web
    ),
    store_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            i.i_item_sk,
            i.i_item_desc,
            d.d_year,
            SUM(sr.sr_net_loss) AS total_store_loss,
            COUNT(*) AS store_return_cnt,
            CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
          AND i.i_product_name LIKE '%Burger%'
        GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_item_desc, d.d_year
    ),
    web_agg AS (
        SELECT
            ws.web_site_sk,
            ws.web_name,
            i.i_item_sk,
            i.i_item_desc,
            d.d_year,
            SUM(wr.wr_net_loss) AS total_web_loss,
            COUNT(*) AS web_return_cnt,
            CASE WHEN SUM(wr.wr_net_loss) > 8000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE i.i_product_name LIKE '%Burger%'
          AND regexp_like(i.i_item_desc, '[0-9]{2}')
        GROUP BY ws.web_site_sk, ws.web_name, i.i_item_sk, i.i_item_desc, d.d_year
    )
SELECT
    COALESCE(s.s_store_sk, sr.sr_store_sk) AS store_sk,
    s.s_store_name,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    CASE WHEN sr.sr_return_amt > 1000 THEN 'BIG' ELSE 'SMALL' END AS amount_category,
    CONCAT(s.s_city, ' - ', s.s_state) AS location,
    (SELECT COUNT(*) FROM cust_common) AS common_return_customers,
    EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = sr.sr_item_sk
          AND inv.inv_quantity_on_hand > 0
    ) AS has_inventory
FROM store s
FULL OUTER JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
WHERE s.s_store_sk IS NOT NULL OR sr.sr_return_amt IS NOT NULL
ORDER BY store_sk
LIMIT 100
