WITH base AS (
    SELECT
        d.d_year,
        ws.web_name,
        ib.ib_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_customer_sk) AS uniq_customers,
        COUNT(DISTINCT cr.cr_order_number) AS uniq_orders,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND w.w_warehouse_sq_ft > 100000
      AND ib.ib_lower_bound >= 50000
      AND p.p_channel_tv = 'Y'
      AND ss.ss_quantity > 50
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_discount_active = 'Y'
            AND p2.p_promo_id = p.p_promo_id
      )
    GROUP BY d.d_year, ws.web_name, ib.ib_income_band_sk
),
ranked AS (
    SELECT
        d_year,
        web_name,
        ib_income_band_sk,
        total_sales,
        total_net_loss,
        uniq_customers,
        uniq_orders,
        avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rnk
    FROM base
)
SELECT
    d_year,
    web_name,
    ib_income_band_sk,
    total_sales,
    total_net_loss,
    uniq_customers,
    uniq_orders,
    avg_return_amt
FROM ranked
WHERE rnk <= 3
ORDER BY d_year, total_sales DESC
LIMIT 100
