WITH
    sales_joined AS (
        SELECT
            ss.ss_net_profit,
            ss.ss_ticket_number,
            p.p_promo_id,
            p.p_promo_name,
            cp.cp_catalog_page_id,
            cp.cp_description,
            cd.cd_gender,
            hd.hd_income_band_sk,
            d_sales.d_year
        FROM store_sales ss
        INNER JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        INNER JOIN date_dim d_sales
            ON ss.ss_sold_date_sk = d_sales.d_date_sk
        INNER JOIN date_dim d_start
            ON p.p_start_date_sk = d_start.d_date_sk
        INNER JOIN catalog_page cp
            ON cp.cp_start_date_sk = d_start.d_date_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE regexp_like(p.p_promo_name, '\\d{2}')
          AND cp.cp_description LIKE '%clearance%'
          AND d_sales.d_year = 2000
    )
SELECT
    p_promo_id,
    cp_catalog_page_id,
    cd_gender,
    SUBSTR(cp_description, 1, 30) AS short_desc,
    CASE WHEN hd_income_band_sk IS NULL THEN 'Unknown' ELSE CAST(hd_income_band_sk AS VARCHAR) END AS income_band,
    SUM(ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss_ticket_number) AS sales_transactions
FROM sales_joined
GROUP BY
    p_promo_id,
    cp_catalog_page_id,
    cd_gender,
    SUBSTR(cp_description, 1, 30),
    CASE WHEN hd_income_band_sk IS NULL THEN 'Unknown' ELSE CAST(hd_income_band_sk AS VARCHAR) END
HAVING SUM(ss_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
