WITH agg_sales AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        COUNT(cr.cr_return_quantity) AS return_count,
        COUNT(DISTINCT ca.ca_address_sk) AS distinct_address_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
     AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_purchase_estimate >= 5000
      AND cd.cd_dep_count <= 2
      AND ss.ss_sales_price > 20
      AND wp.wp_type = 'content'
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
    GROUP BY ca.ca_address_id, ca.ca_city, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT
    ca_address_id,
    ca_city,
    cd_demo_sk,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    total_store_net_paid,
    total_web_net_paid,
    return_count,
    distinct_address_cnt,
    RANK() OVER (PARTITION BY cd_gender ORDER BY (total_store_net_paid + total_web_net_paid) DESC) AS gender_profit_rank,
    ROW_NUMBER() OVER (ORDER BY (total_store_net_paid + total_web_net_paid) DESC) AS overall_profit_rank
FROM agg_sales
ORDER BY overall_profit_rank
LIMIT 100
