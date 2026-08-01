WITH base_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        c.c_customer_id,
        ca.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p_ws.p_promo_name,
        r.r_reason_desc,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        sr.sr_return_amt AS store_return_amount,
        wr.wr_return_amt AS web_return_amount,
        cs.cs_quantity,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_quantity DESC) AS cs_qty_rank
    FROM
        date_dim d
        INNER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
        INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
        LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
            AND wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        d.d_year = 2000
        AND ca.ca_country = 'United States'
        AND s.s_state = 'TX'
        AND ib.ib_upper_bound >= 80000
        AND p_ws.p_discount_active = 'Y'
),
agg_sales AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_name,
        c_customer_id,
        ca_state,
        p_promo_name,
        SUM(COALESCE(catalog_sales_amount, 0) + COALESCE(web_sales_amount, 0) - COALESCE(store_return_amount, 0) - COALESCE(web_return_amount, 0)) AS net_sales,
        COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
        AVG(cs_quantity) AS avg_catalog_qty,
        AVG(ws_quantity) AS avg_web_qty
    FROM base_sales
    GROUP BY
        d_year,
        d_month_seq,
        s_store_name,
        c_customer_id,
        ca_state,
        p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    c_customer_id,
    ca_state,
    p_promo_name,
    net_sales,
    distinct_return_reasons,
    avg_catalog_qty,
    avg_web_qty,
    ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM agg_sales
WHERE net_sales > 10000
ORDER BY net_sales DESC
LIMIT 100
