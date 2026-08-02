WITH sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)   -- approximate 10% random sample of items
    WHERE i_formulation LIKE 'snow%'
      AND i_brand_id = 1001001
)
SELECT
    s.s_store_id,
    s.s_city,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM
    web_sales ws
    RIGHT OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN sampled_item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND d.d_week_seq = 8
    AND s.s_state = 'CA'
    AND w.w_city = 'Los Angeles'
    AND cc.cc_name = 'Call Center 1'
    AND sr.sr_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_brand_id = 2002002
    )
GROUP BY
    s.s_store_id,
    s.s_city,
    d.d_year
ORDER BY
    total_net_profit DESC
LIMIT 100
