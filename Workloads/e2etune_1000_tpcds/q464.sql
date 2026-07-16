SELECT
    COALESCE(sales.ca_country, returns.ca_country) AS country,
    returns.wp_type AS page_type,
    COALESCE(sales.total_net_profit, 0) AS total_net_profit,
    COALESCE(returns.total_net_loss, 0) AS total_net_loss,
    COALESCE(sales.total_net_profit, 0) - COALESCE(returns.total_net_loss, 0) AS net_revenue,
    COALESCE(sales.sales_cnt, 0) AS sales_cnt,
    COALESCE(returns.returns_cnt, 0) AS returns_cnt,
    RANK() OVER (ORDER BY COALESCE(sales.total_net_profit, 0) - COALESCE(returns.total_net_loss, 0) DESC) AS revenue_rank
FROM (
    SELECT
        ca.ca_country,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND cs.cs_net_paid_inc_ship_tax > 1000
    GROUP BY ca.ca_country
) sales
FULL OUTER JOIN (
    SELECT
        ca.ca_country,
        wp.wp_type,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450820 AND 2450826
      AND wr.wr_net_loss > 0
    GROUP BY ca.ca_country, wp.wp_type
) returns
ON sales.ca_country = returns.ca_country
ORDER BY net_revenue DESC
LIMIT 100
