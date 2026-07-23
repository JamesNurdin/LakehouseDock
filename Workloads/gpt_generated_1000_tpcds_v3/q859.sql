WITH
catalog_sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_call_center_sk,
        cs_bill_cdemo_sk,
        cs_bill_addr_sk,
        SUM(cs_net_profit) AS cat_net_profit,
        SUM(cs_quantity) AS cat_quantity
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_sold_time_sk, cs_call_center_sk, cs_bill_cdemo_sk, cs_bill_addr_sk
),
store_sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_cdemo_sk,
        ss_addr_sk,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk, ss_cdemo_sk, ss_addr_sk
),
web_sales_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_cdemo_sk,
        ws_bill_addr_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_sold_time_sk, ws_bill_cdemo_sk, ws_bill_addr_sk, ws_web_page_sk, ws_web_site_sk
),
catalog_returns_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_reason_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_addr_sk,
        SUM(cr_net_loss) AS returns_net_loss,
        SUM(cr_return_quantity) AS returns_quantity
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_returned_time_sk, cr_call_center_sk, cr_reason_sk, cr_refunded_cdemo_sk, cr_refunded_addr_sk
),
combined AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d_cat.d_year,
        d_cat.d_date,
        SUM(cat_agg.cat_net_profit) AS cat_net_profit,
        SUM(store_agg.store_net_profit) AS store_net_profit,
        SUM(web_agg.web_net_profit) AS web_net_profit,
        SUM(COALESCE(ret_agg.returns_net_loss,0)) AS returns_net_loss,
        SUM(cat_agg.cat_quantity) AS cat_quantity,
        SUM(store_agg.store_quantity) AS store_quantity,
        SUM(web_agg.web_quantity) AS web_quantity,
        SUM(COALESCE(ret_agg.returns_quantity,0)) AS returns_quantity,
        SUM(cat_agg.cat_net_profit + store_agg.store_net_profit + web_agg.web_net_profit - COALESCE(ret_agg.returns_net_loss,0)) AS total_net_profit,
        SUM(cat_agg.cat_quantity + store_agg.store_quantity + web_agg.web_quantity - COALESCE(ret_agg.returns_quantity,0)) AS total_quantity,
        CASE WHEN SUM(cat_agg.cat_net_profit + store_agg.store_net_profit + web_agg.web_net_profit - COALESCE(ret_agg.returns_net_loss,0)) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_status
    FROM catalog_sales_agg cat_agg
    JOIN item i ON cat_agg.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cat ON cat_agg.cs_sold_date_sk = d_cat.d_date_sk
    JOIN call_center cc_sales ON cat_agg.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    JOIN customer_demographics cd_cat ON cat_agg.cs_bill_cdemo_sk = cd_cat.cd_demo_sk
    JOIN customer_address ca_cat ON cat_agg.cs_bill_addr_sk = ca_cat.ca_address_sk
    JOIN time_dim t_cat ON cat_agg.cs_sold_time_sk = t_cat.t_time_sk
    -- store sales
    JOIN store_sales_agg store_agg ON store_agg.ss_item_sk = i.i_item_sk
    JOIN date_dim d_store ON store_agg.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t_store ON store_agg.ss_sold_time_sk = t_store.t_time_sk
    JOIN customer_demographics cd_store ON store_agg.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN customer_address ca_store ON store_agg.ss_addr_sk = ca_store.ca_address_sk
    -- web sales
    JOIN web_sales_agg web_agg ON web_agg.ws_item_sk = i.i_item_sk
    JOIN date_dim d_web ON web_agg.ws_sold_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON web_agg.ws_sold_time_sk = t_web.t_time_sk
    JOIN customer_demographics cd_web ON web_agg.ws_bill_cdemo_sk = cd_web.cd_demo_sk
    JOIN customer_address ca_web ON web_agg.ws_bill_addr_sk = ca_web.ca_address_sk
    LEFT JOIN catalog_returns_agg ret_agg ON ret_agg.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON ret_agg.cr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc_ret ON ret_agg.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN date_dim d_ret ON ret_agg.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret ON ret_agg.cr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN customer_demographics cd_ret ON ret_agg.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN customer_address ca_ret ON ret_agg.cr_refunded_addr_sk = ca_ret.ca_address_sk
    LEFT JOIN web_page wp ON web_agg.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN web_site ws ON web_agg.ws_web_site_sk = ws.web_site_sk
    LEFT JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE
        d_cat.d_year = 2001
        AND i.i_category_id IN (1,5,9)
        AND cc_sales.cc_state = 'CA'
        AND t_cat.t_hour BETWEEN 9 AND 17
        AND r.r_reason_desc = 'Damaged'
        AND p.p_discount_active = 'Y'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        d_cat.d_year,
        d_cat.d_date
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    d_date,
    cat_net_profit,
    store_net_profit,
    web_net_profit,
    returns_net_loss,
    total_net_profit,
    total_quantity,
    profit_status,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year
FROM combined
ORDER BY total_net_profit DESC, profit_rank_year
LIMIT 100
