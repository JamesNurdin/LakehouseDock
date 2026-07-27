WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_buyers
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450875 AND 2450900
      AND cs.cs_ext_list_price > 5000
      AND cd.cd_gender = 'M'
      AND w.w_state = 'CA'
      AND cs.cs_call_center_sk IN (10, 16, 22)
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450875 AND 2450900
      AND cr.cr_return_amount > 100
      AND cd_ref.cd_gender = 'F'
      AND w.w_state = 'CA'
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_buyers
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450875 AND 2450900
      AND ws.ws_ext_list_price > 5000
      AND cd.cd_gender = 'M'
      AND w.w_state = 'CA'
    GROUP BY ws.ws_item_sk, ws.ws_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_color,
    i.i_brand,
    w.w_warehouse_name,
    s.total_sales,
    s.total_profit,
    s.distinct_buyers,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt,
    we.total_web_sales,
    we.total_web_profit,
    we.distinct_web_buyers
FROM sales_agg s
JOIN returns_agg r ON s.cs_item_sk = r.cr_item_sk AND s.cs_warehouse_sk = r.cr_warehouse_sk
JOIN web_agg we ON s.cs_item_sk = we.ws_item_sk AND s.cs_warehouse_sk = we.ws_warehouse_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY s.total_sales DESC
LIMIT 100
