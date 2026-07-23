WITH item_codes AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        regexp_extract(i.i_item_desc, '([A-Z]{3})', 1) AS code3,
        i.i_brand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_item_desc, '[0-9]{2}')
),
store_brand_profit AS (
    SELECT
        s.s_store_name,
        s.s_city,
        ic.i_brand,
        ic.code3,
        SUM(ic.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        s.s_store_sk
    FROM item_codes ic
    JOIN store s ON ic.ss_store_sk = s.s_store_sk
    WHERE s.s_city LIKE '%York%'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
          WHERE sr.sr_ticket_number = ic.ss_ticket_number
            AND dr.d_year = 2002
            AND sr.sr_return_quantity > 0
      )
    GROUP BY s.s_store_name, s.s_city, ic.i_brand, ic.code3, s.s_store_sk
)
SELECT
    sbp.s_store_name,
    substring(sbp.s_store_name, 1, 15) AS short_name,
    sbp.s_city,
    sbp.i_brand,
    sbp.code3,
    sbp.total_net_profit,
    sbp.sales_cnt,
    sbp.total_net_profit / COALESCE(
        (
            SELECT SUM(ss2.ss_net_profit)
            FROM store_sales ss2
            JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
            JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
            WHERE s2.s_store_sk = sbp.s_store_sk
              AND d2.d_year = 2002
        ), 1
    ) AS profit_ratio
FROM store_brand_profit sbp
WHERE sbp.total_net_profit > (
    SELECT AVG(brand_profit)
    FROM (
        SELECT SUM(ss3.ss_net_profit) AS brand_profit
        FROM store_sales ss3
        JOIN item i3 ON ss3.ss_item_sk = i3.i_item_sk
        JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
        WHERE ss3.ss_store_sk = sbp.s_store_sk
          AND d3.d_year = 2002
          AND regexp_like(i3.i_item_desc, '[0-9]{2}')
        GROUP BY i3.i_brand
    ) avg_brands
)
ORDER BY total_net_profit DESC
LIMIT 100
