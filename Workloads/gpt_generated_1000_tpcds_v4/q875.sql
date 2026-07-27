WITH joined_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        p.p_discount_active,
        i.i_item_sk,
        i.i_current_price,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        sr.sr_return_amt,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* store related tables */
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    /* inventory (no columns needed in final select, but included to satisfy join‑all requirement) */
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    /* web sales */
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    /* web returns */
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_sales_price > 500
      AND ws.ws_ext_sales_price > 500
      AND i.i_current_price BETWEEN 10 AND 100
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound >= 50000
      AND p.p_discount_active = 'Y'
),
sales_agg AS (
    SELECT
        s_store_id,
        p_promo_id,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_return_amt) AS total_store_returns,
        SUM(wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        CASE WHEN ib_upper_bound > 80000 THEN 'High' ELSE 'Low' END AS income_category
    FROM joined_data
    GROUP BY s_store_id, p_promo_id, ib_upper_bound
)
SELECT
    p_promo_id,
    AVG(total_catalog_sales + total_web_sales) AS avg_total_sales,
    SUM(total_store_returns + total_web_returns) AS total_returns,
    CASE WHEN SUM(total_store_returns + total_web_returns) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag,
    income_category
FROM sales_agg
GROUP BY p_promo_id, income_category
HAVING AVG(total_catalog_sales + total_web_sales) > 1000
ORDER BY avg_total_sales DESC
LIMIT 100
