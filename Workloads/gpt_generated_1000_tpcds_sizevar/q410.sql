WITH store_item_excl AS (
    SELECT DISTINCT sr.sr_item_sk
    FROM store_returns sr
    EXCEPT
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
),
agg_store AS (
    SELECT
        s.s_store_id AS location_id,
        d.d_year AS year,
        i.i_category AS category,
        r.r_reason_desc AS reason_desc,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt,
        SUM(sr.sr_return_amt) AS total_amount,
        AVG(sr.sr_return_quantity) AS avg_metric,
        MIN(sr.sr_return_amt) AS min_amount,
        MAX(sr.sr_return_amt) AS max_amount
    FROM store s
    RIGHT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND r.r_reason_id = 'R001'
      AND sr.sr_item_sk IN (SELECT sr_item_sk FROM store_item_excl)
    GROUP BY s.s_store_id, d.d_year, i.i_category, r.r_reason_desc
),
agg_web AS (
    SELECT
        w.w_warehouse_id AS location_id,
        d.d_year AS year,
        i.i_category AS category,
        r.r_reason_desc AS reason_desc,
        COUNT(DISTINCT ws.ws_order_number) AS cnt,
        SUM(ws.ws_net_paid) AS total_amount,
        AVG(ws.ws_quantity) AS avg_metric,
        MIN(ws.ws_sales_price) AS min_amount,
        MAX(ws.ws_sales_price) AS max_amount
    FROM web_sales ws
    RIGHT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND r.r_reason_id = 'R001'
    GROUP BY w.w_warehouse_id, d.d_year, i.i_category, r.r_reason_desc
)
SELECT * FROM agg_store
UNION
SELECT * FROM agg_web
LIMIT 100
