WITH promo_metrics AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        SUM(ss.ss_net_profit) AS ss_total_net_profit,
        SUM(sr.sr_net_loss) AS sr_total_loss,
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss)) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
        AND ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN web_site ws
        ON ws.web_state = 'CA'
    JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    WHERE
        d_cs.d_year = 2001
        AND p.p_discount_active = 'Y'
        AND cc.cc_country = 'USA'
        AND cd_bill.cd_gender = 'M'
        AND cs.cs_quantity > 1
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        p.p_promo_sk,
        p.p_promo_name
),
ranked_promos AS (
    SELECT
        pm.cc_name,
        pm.p_promo_name,
        pm.total_profit,
        CASE
            WHEN pm.total_profit > (SELECT AVG(total_profit) FROM promo_metrics) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category,
        RANK() OVER (PARTITION BY pm.cc_name ORDER BY pm.total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY pm.total_profit DESC) AS overall_dense_rank,
        pm.num_catalog_sales,
        pm.num_store_sales,
        pm.num_returns,
        (SELECT COUNT(DISTINCT p2.p_promo_sk) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_total
    FROM promo_metrics pm
)
SELECT
    cc_name,
    p_promo_name,
    total_profit,
    profit_category,
    profit_rank,
    overall_dense_rank,
    num_catalog_sales,
    num_store_sales,
    num_returns,
    active_promo_total
FROM ranked_promos
WHERE profit_rank <= 10
ORDER BY cc_name, profit_rank
LIMIT 100
