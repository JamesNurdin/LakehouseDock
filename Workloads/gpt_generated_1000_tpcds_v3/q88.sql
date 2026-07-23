WITH cs_agg AS (
    SELECT
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        AVG(cs_sales_price) AS avg_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451195
    GROUP BY cs_catalog_page_sk, cs_promo_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk, cs_bill_addr_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_country,
    s.s_tax_percentage,
    cp.cp_department,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ca.ca_state,
    cs_agg.total_quantity,
    cs_agg.total_sales,
    cs_agg.avg_sales_price,
    sr.sr_return_amt,
    sr.sr_return_tax,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wp.wp_type,
    SUM(cs_agg.total_sales) OVER (PARTITION BY s.s_store_id) AS store_total_sales,
    SUM(sr.sr_return_amt) OVER (PARTITION BY s.s_store_id) AS store_total_return_amt,
    SUM(wr.wr_return_amt) OVER (PARTITION BY s.s_store_id) AS store_total_web_return_amt,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY cs_agg.total_sales DESC) AS sales_rank
FROM cs_agg
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    s.s_country = 'United States'
    AND s.s_tax_percentage > 0.05
    AND cp.cp_department = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'F'
    AND cd.cd_education_status = 'College'
    AND hd.hd_buy_potential = 'high'
    AND ca.ca_state = 'CA'
    AND cs_agg.total_sales > 5000
    AND wp.wp_type = 'product'
LIMIT 100
