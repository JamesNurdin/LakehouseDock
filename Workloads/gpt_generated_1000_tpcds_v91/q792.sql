WITH sales AS (
    SELECT
        ca_bill.ca_state AS state,
        d_sold.d_year AS year,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_net_profit ELSE 0 END) AS total_promo_active_profit,
        0.0 AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN inventory inv ON d_sold.d_date_sk = inv.inv_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE d_sold.d_year BETWEEN 1998 AND 2000
      AND ca_bill.ca_state IN ('CA','TX','NY')
      AND cs.cs_net_profit > 500
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND ws.ws_quantity >= 1
      AND wp.wp_type = 'article'
      AND wr.wr_net_loss > 100
      AND wr.wr_fee > 10
    GROUP BY ca_bill.ca_state, d_sold.d_year
),
returns AS (
    SELECT
        ca_bill.ca_state AS state,
        d_sold.d_year AS year,
        0.0 AS total_sales_profit,
        0.0 AS total_promo_active_profit,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN inventory inv ON d_sold.d_date_sk = inv.inv_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE d_sold.d_year BETWEEN 1998 AND 2000
      AND ca_bill.ca_state IN ('CA','TX','NY')
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND ws.ws_quantity >= 1
      AND wp.wp_type = 'article'
      AND wr.wr_net_loss > 100
      AND wr.wr_fee > 10
    GROUP BY ca_bill.ca_state, d_sold.d_year
),
combined AS (
    SELECT * FROM sales
    UNION
    SELECT * FROM returns
),
final AS (
    SELECT
        state,
        year,
        total_sales_profit,
        total_return_loss,
        total_sales_profit - total_return_loss AS net_amount,
        CASE WHEN (total_sales_profit - total_return_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY year) AS rn_state_year
    FROM combined
)
SELECT
    state,
    year,
    profit_category,
    SUM(net_amount) AS sum_net_amount,
    AVG(net_amount) AS avg_net_amount,
    MAX(rn_state_year) AS max_rn_state_year
FROM final
GROUP BY ROLLUP (state, year, profit_category)
HAVING SUM(net_amount) > 0
ORDER BY state, year
LIMIT 100
