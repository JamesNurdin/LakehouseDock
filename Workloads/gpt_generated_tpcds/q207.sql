WITH brand_month_sales AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_brand,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS total_orders,
        COUNT(CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 END) AS promo_orders
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_brand
)
SELECT
    bms.d_year,
    bms.month,
    bms.i_brand,
    bms.total_net_profit,
    bms.total_quantity,
    bms.avg_discount_amt,
    bms.distinct_customers,
    bms.total_orders,
    bms.promo_orders,
    RANK() OVER (PARTITION BY bms.d_year, bms.month ORDER BY bms.total_net_profit DESC) AS profit_rank
FROM brand_month_sales bms
ORDER BY bms.d_year, bms.month, profit_rank
