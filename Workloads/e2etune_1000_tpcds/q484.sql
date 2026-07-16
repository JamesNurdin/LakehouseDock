WITH inventory_agg AS (
    SELECT
        inv_date_sk,
        AVG(inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory
    GROUP BY inv_date_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(i.avg_inventory_qty) AS avg_inventory_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory_agg i ON i.inv_date_sk = ss.ss_sold_date_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_state
),
store_returns_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_state
),
web_returns_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS num_web_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    s.d_year,
    s.ca_state,
    s.num_sales,
    s.total_net_profit,
    s.total_discount,
    s.avg_coupon_amt,
    s.distinct_customers,
    s.avg_inventory_qty,
    COALESCE(r.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(r.total_store_return_qty, 0) AS total_store_return_qty,
    COALESCE(r.num_store_returns, 0) AS num_store_returns,
    COALESCE(w.total_web_return_loss, 0) AS total_web_return_loss,
    COALESCE(w.num_web_returns, 0) AS num_web_returns
FROM sales_agg s
LEFT JOIN store_returns_agg r
    ON s.d_year = r.d_year AND s.ca_state = r.ca_state
LEFT JOIN web_returns_agg w
    ON s.d_year = w.d_year AND s.ca_state = w.ca_state
ORDER BY s.total_net_profit DESC
LIMIT 100
