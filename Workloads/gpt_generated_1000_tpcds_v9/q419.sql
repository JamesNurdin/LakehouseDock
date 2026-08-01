WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        d.d_date,
        i.i_manufact,
        i.i_item_desc,
        p.p_promo_name,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)special')
      AND p.p_promo_name LIKE '%Discount%'
      AND substring(ca.ca_state FROM 1 FOR 2) = 'CA'
      AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_state = ca.ca_state
              AND regexp_like(cc.cc_name, '^.*Call Center.*$')
      )
),
aggregated_sales AS (
    SELECT
        fs.i_manufact,
        sum(fs.cs_net_paid) AS total_net_paid,
        sum(fs.cs_net_profit) AS total_net_profit,
        avg(fs.cs_quantity) AS avg_quantity,
        regexp_extract(min(fs.i_item_desc), '(?i)(special)', 1) AS extracted_special,
        concat(min(fs.ca_city), ', ', min(fs.ca_state)) AS sample_city_state,
        (SELECT max(ib_lower_bound) FROM income_band) AS max_income_lower
    FROM filtered_sales fs
    GROUP BY fs.i_manufact
)
SELECT
    agg.i_manufact,
    agg.total_net_paid,
    agg.total_net_profit,
    agg.avg_quantity,
    agg.extracted_special,
    agg.sample_city_state,
    agg.max_income_lower,
    rank() OVER (ORDER BY agg.total_net_paid DESC) AS manufacturer_rank
FROM aggregated_sales agg
ORDER BY manufacturer_rank
LIMIT 100
