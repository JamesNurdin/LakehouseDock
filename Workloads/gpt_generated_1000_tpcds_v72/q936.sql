WITH store_return_agg AS (
    SELECT
        sr.sr_reason_sk,
        SUM(sr.sr_net_loss) AS reason_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_reason_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_dep_count <= 3
      AND cs.cs_quantity > 5
      AND p.p_discount_active = 'Y'
      AND cp.cp_catalog_number IN (3, 4, 8)
      AND wr.wr_return_quantity > 0
    GROUP BY
        d.d_year,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_sk
    HAVING SUM(cs.cs_ext_sales_price) > 100000
)
SELECT
    sa.cp_catalog_number,
    sa.cp_catalog_page_number,
    sa.p_promo_name,
    sa.hd_income_band_sk,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    sa.total_sales,
    sa.total_profit,
    ra.reason_return_loss,
    CASE WHEN sa.total_profit > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN store_return_agg ra ON ra.sr_reason_sk = sa.r_reason_sk
ORDER BY profit_rank
LIMIT 100
