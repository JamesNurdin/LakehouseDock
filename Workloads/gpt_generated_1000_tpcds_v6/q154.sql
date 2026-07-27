WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_sold_date_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_ext_discount_amt) AS total_discount
    FROM catalog_sales
    WHERE cs_ext_wholesale_cost > 500
    GROUP BY cs_call_center_sk, cs_bill_addr_sk, cs_bill_cdemo_sk, cs_sold_date_sk
)
SELECT
    cc.cc_call_center_id,
    ca.ca_state,
    cd.cd_gender,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(cs_agg.total_net_paid) AS total_catalog_net_paid,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    CASE
        WHEN SUM(cs_agg.total_net_paid) > 50000 THEN 'Very High'
        ELSE 'Normal'
    END AS catalog_sales_category
FROM cs_agg
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca
    ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
   AND ss.ss_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE
    cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cd.cd_gender = 'F'
    AND ss.ss_quantity > 5
    AND cs_agg.total_discount > 1000
GROUP BY
    cc.cc_call_center_id,
    ca.ca_state,
    cd.cd_gender
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY
    total_store_profit DESC
LIMIT 100
