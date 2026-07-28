WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_store_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        ss_ticket_number,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_sales_price > 0
      AND ss_net_profit IS NOT NULL
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_store_sk, ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk, ss_promo_sk, ss_ticket_number
),
joined_data AS (
    SELECT
        sa.ss_item_sk,
        i.i_brand,
        i.i_category,
        d_sales.d_year,
        s.s_state,
        p.p_discount_active,
        sm.sm_contract,
        r_sr.r_reason_desc AS store_return_reason,
        cr.cr_return_amount,
        ws.ws_quantity,
        sa.total_net_profit,
        sa.sales_cnt,
        COALESCE(sr.sr_net_loss, 0)                AS store_return_loss,
        COALESCE(cr.cr_return_amount, 0)           AS catalog_return_amount,
        COALESCE(wr.wr_return_amt, 0)              AS web_return_amount
    FROM ss_agg sa
    JOIN item i               ON i.i_item_sk = sa.ss_item_sk
    JOIN date_dim d_sales     ON d_sales.d_date_sk = sa.ss_sold_date_sk
    JOIN store s              ON s.s_store_sk = sa.ss_store_sk
    JOIN customer c           ON c.c_customer_sk = sa.ss_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = sa.ss_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sa.ss_hdemo_sk
    JOIN promotion p          ON p.p_promo_sk = sa.ss_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = sa.ss_ticket_number
       AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON r_sr.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN reason r_cr
        ON r_cr.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_contract LIKE 'A%'
      AND r_sr.r_reason_desc = 'Customer Not Satisfied'
      AND cr.cr_return_amount > 100.00
      AND ws.ws_quantity > 5
),
agg AS (
    SELECT
        jd.i_brand,
        jd.i_category,
        jd.d_year,
        SUM(jd.total_net_profit)                     AS brand_year_profit,
        SUM(jd.store_return_loss + jd.catalog_return_amount + jd.web_return_amount) AS total_returns
    FROM joined_data jd
    GROUP BY jd.i_brand, jd.i_category, jd.d_year
    HAVING SUM(jd.total_net_profit) > 0
)
SELECT
    a.i_brand,
    a.i_category,
    a.d_year,
    a.brand_year_profit,
    a.total_returns,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.brand_year_profit DESC) AS rank_in_category
FROM agg a
ORDER BY a.brand_year_profit DESC
LIMIT 100
