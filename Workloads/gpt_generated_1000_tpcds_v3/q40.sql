WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS line_item_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450890 AND 2452167
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_wholesale_cost > 30
    GROUP BY cs.cs_order_number, cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, cs.cs_ship_mode_sk
),
return_agg AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr.cr_return_amount > 0
    GROUP BY cr.cr_order_number
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    sm.sm_ship_mode_id,
    sm.sm_code,
    wp.wp_url,
    COUNT(DISTINCT s.cs_order_number) AS num_orders,
    SUM(s.total_sales) AS total_sales_amount,
    SUM(s.total_net_paid) AS total_net_paid_amount,
    SUM(COALESCE(r.total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(r.total_return_loss, 0)) AS total_return_loss,
    SUM(s.line_item_cnt) AS total_line_items,
    SUM(COALESCE(r.return_cnt, 0)) AS total_returns
FROM sales_agg s
LEFT JOIN return_agg r ON s.cs_order_number = r.cr_order_number
JOIN customer c ON c.c_customer_sk = s.cs_bill_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = s.cs_bill_cdemo_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = s.cs_ship_mode_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1975
  AND sm.sm_code = 'AIR'
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    sm.sm_ship_mode_id,
    sm.sm_code,
    wp.wp_url
ORDER BY total_sales_amount DESC
LIMIT 100
