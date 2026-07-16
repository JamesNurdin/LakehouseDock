WITH sales_union AS (
    SELECT
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_bill_addr_sk AS addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
    UNION ALL
    SELECT
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_addr_sk AS addr_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
)
SELECT
    COALESCE(category, 'ALL') AS category,
    COALESCE(promo_name, 'ALL') AS promo_name,
    COALESCE(gender, 'ALL') AS gender,
    total_net_profit,
    total_net_paid_inc_tax,
    transaction_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        cd.cd_gender AS gender,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(*) AS transaction_count
    FROM sales_union s
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN promotion p ON s.promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON s.addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY CUBE(i.i_category, p.p_promo_name, cd.cd_gender)
    HAVING SUM(s.net_profit) > 500
) agg
ORDER BY total_net_profit DESC
LIMIT 20
