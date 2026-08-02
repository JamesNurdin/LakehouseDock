WITH agg_sales AS (
    SELECT 
        ss_item_sk,
        ss_sold_date_sk,
        ss_hdemo_sk,
        ss_customer_sk,
        ss_addr_sk,
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_hdemo_sk, ss_customer_sk, ss_addr_sk, ss_store_sk
),
full_returns AS (
    SELECT 
        COALESCE(cr.cr_returned_date_sk, wr.wr_returned_date_sk) AS returned_date_sk,
        COALESCE(cr.cr_returned_time_sk, wr.wr_returned_time_sk) AS returned_time_sk,
        COALESCE(cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
        COALESCE(cr.cr_refunded_customer_sk, wr.wr_refunded_customer_sk) AS refunded_customer_sk,
        COALESCE(cr.cr_refunded_hdemo_sk, wr.wr_refunded_hdemo_sk) AS refunded_hdemo_sk,
        COALESCE(cr.cr_refunded_addr_sk, wr.wr_refunded_addr_sk) AS refunded_addr_sk,
        COALESCE(cr.cr_returning_customer_sk, wr.wr_returning_customer_sk) AS returning_customer_sk,
        COALESCE(cr.cr_returning_hdemo_sk, wr.wr_returning_hdemo_sk) AS returning_hdemo_sk,
        COALESCE(cr.cr_returning_addr_sk, wr.wr_returning_addr_sk) AS returning_addr_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk AS cr_reason_sk,
        wr.wr_reason_sk AS wr_reason_sk,
        COALESCE(cr.cr_return_quantity, wr.wr_return_quantity) AS return_quantity,
        COALESCE(cr.cr_return_amount, wr.wr_return_amt) AS return_amount,
        COALESCE(cr.cr_net_loss, wr.wr_net_loss) AS net_loss
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
        ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
        AND cr.cr_item_sk = wr.wr_item_sk
)
SELECT
    ds.d_year,
    I_sales.i_item_id,
    I_sales.i_product_name,
    S.s_store_id,
    S.s_state,
    C.c_first_name,
    C.c_last_name,
    asales.total_sales,
    asales.total_profit,
    CASE WHEN asales.total_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY ds.d_year ORDER BY asales.total_sales DESC) AS sales_rank_year,
    CASE WHEN FR.return_quantity IS NOT NULL AND FR.return_quantity > 0 THEN 'Returned' ELSE 'No Return' END AS return_status,
    COALESCE(R1.r_reason_desc, R2.r_reason_desc) AS return_reason,
    CP.cp_description,
    SM.sm_type,
    (
        SELECT AVG(ib_sub.ib_lower_bound)
        FROM income_band ib_sub
        WHERE ib_sub.ib_income_band_sk = HD.hd_income_band_sk
    ) AS avg_income_lower
FROM agg_sales AS asales
JOIN item I_sales
    ON asales.ss_item_sk = I_sales.i_item_sk
JOIN date_dim ds
    ON asales.ss_sold_date_sk = ds.d_date_sk
JOIN household_demographics HD
    ON asales.ss_hdemo_sk = HD.hd_demo_sk
JOIN income_band IB
    ON HD.hd_income_band_sk = IB.ib_income_band_sk
JOIN customer C
    ON asales.ss_customer_sk = C.c_customer_sk
JOIN customer_address CA
    ON asales.ss_addr_sk = CA.ca_address_sk
JOIN store S
    ON asales.ss_store_sk = S.s_store_sk
JOIN promotion P
    ON I_sales.i_item_sk = P.p_item_sk
LEFT JOIN full_returns FR
    ON FR.item_sk = I_sales.i_item_sk
LEFT JOIN date_dim dr
    ON FR.returned_date_sk = dr.d_date_sk
LEFT JOIN time_dim tr
    ON FR.returned_time_sk = tr.t_time_sk
LEFT JOIN catalog_page CP
    ON FR.cr_catalog_page_sk = CP.cp_catalog_page_sk
LEFT JOIN ship_mode SM
    ON FR.cr_ship_mode_sk = SM.sm_ship_mode_sk
LEFT JOIN reason R1
    ON FR.cr_reason_sk = R1.r_reason_sk
LEFT JOIN reason R2
    ON FR.wr_reason_sk = R2.r_reason_sk
LEFT JOIN customer C_refunded
    ON FR.refunded_customer_sk = C_refunded.c_customer_sk
LEFT JOIN customer_address CA_refunded
    ON FR.refunded_addr_sk = CA_refunded.ca_address_sk
LEFT JOIN household_demographics HD_refunded
    ON FR.refunded_hdemo_sk = HD_refunded.hd_demo_sk
WHERE ds.d_year = 2001
  AND I_sales.i_brand = 'Brand#45'
  AND S.s_state = 'CA'
  AND C.c_birth_year BETWEEN 1950 AND 1960
  AND IB.ib_upper_bound >= 170000
  AND P.p_channel_details LIKE '%old%'
ORDER BY sales_rank_year, asales.total_sales DESC
LIMIT 100
