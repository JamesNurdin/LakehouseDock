WITH avg_promo_cost AS (
    SELECT p_promo_sk, AVG(p_cost) AS avg_cost
    FROM promotion
    GROUP BY p_promo_sk
)
SELECT
    ca_sales.ca_city,
    cd_sales.cd_marital_status,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(wr.wr_refunded_cash) AS total_refunds,
    SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss) AS net_margin,
    CASE WHEN SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    AVG(avg_promo_cost.avg_cost) AS avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY ca_sales.ca_city ORDER BY SUM(ss.ss_net_paid) DESC) AS city_sales_rank
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd_sales.cd_demo_sk
JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN avg_promo_cost ON p.p_promo_sk = avg_promo_cost.p_promo_sk
WHERE ca_sales.ca_state = 'CA'
  AND cd_sales.cd_purchase_estimate > 5000
GROUP BY
    ca_sales.ca_city,
    cd_sales.cd_marital_status,
    p.p_promo_name,
    avg_promo_cost.avg_cost
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY total_sales DESC
LIMIT 100
