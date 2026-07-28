WITH sales_summary AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        cd.cd_education_status,
        w.w_warehouse_name,
        w.w_street_type,
        s.s_state,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_warehouse_sk AS ws_warehouse_sk,
        ws.ws_web_site_sk,
        site.web_name,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN "store" s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE
        cd.cd_credit_rating IN ('Low Risk', 'High Risk')
        AND cd.cd_education_status = 'College'
        AND w.w_street_type = 'Road'
        AND s.s_state = 'CA'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
        AND cs.cs_ext_sales_price > 1000
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_amt > 0
        )
)
SELECT
    ss.cs_order_number,
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_credit_rating,
    ss.w_warehouse_name,
    ss.sr_return_amt,
    ss.ws_ext_sales_price,
    ss.total_sales_ext,
    RANK() OVER (PARTITION BY ss.cd_credit_rating ORDER BY ss.total_sales_ext DESC) AS credit_rating_rank,
    ROW_NUMBER() OVER (ORDER BY ss.total_sales_ext DESC) AS overall_rank
FROM (
    SELECT
        ss.*, 
        (ss.cs_ext_sales_price + ss.ws_ext_sales_price) AS total_sales_ext
    FROM sales_summary ss
) ss
ORDER BY overall_rank
LIMIT 100
