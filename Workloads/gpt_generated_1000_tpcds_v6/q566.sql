WITH filtered AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cp.cp_catalog_page_number,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code,
        substring(p.p_promo_name, 1, 10) AS promo_short,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        i.inv_quantity_on_hand,
        cp.cp_type,
        cp.cp_description
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)stores')
      AND cp.cp_description LIKE '%girls%'
)
SELECT
    d_year,
    d_month_seq,
    cp_catalog_page_number,
    promo_code,
    promo_short,
    sum(ss_net_profit) AS total_net_profit,
    sum(ss_ext_sales_price) AS total_sales_price,
    avg(inv_quantity_on_hand) AS avg_quantity_on_hand,
    count(*) AS sales_cnt,
    concat(cp_type, ': ', cp_description) AS page_type_desc
FROM filtered
GROUP BY
    d_year,
    d_month_seq,
    cp_catalog_page_number,
    promo_code,
    promo_short,
    cp_type,
    cp_description
ORDER BY total_net_profit DESC
LIMIT 100
