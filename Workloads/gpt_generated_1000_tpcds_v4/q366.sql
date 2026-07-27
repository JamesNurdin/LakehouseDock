WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand_id = 1003001
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND cc.cc_market_manager = 'David Smith'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    store_sales_profit,
    web_sales_profit,
    (store_sales_profit + web_sales_profit) AS total_profit,
    CASE
        WHEN (store_sales_profit + web_sales_profit) > (
            SELECT AVG(store_sales_profit + web_sales_profit) FROM sales_agg
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    RANK() OVER (ORDER BY (store_sales_profit + web_sales_profit) DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
