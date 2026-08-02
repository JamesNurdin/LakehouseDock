WITH eligible_items AS (
    SELECT i.i_item_id
    FROM item i
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
),
excluded_items AS (
    SELECT i.i_item_id
    FROM item i
    JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    WHERE sr.sr_return_quantity > 5
),
final_items AS (
    SELECT i_item_id FROM eligible_items
    EXCEPT
    SELECT i_item_id FROM excluded_items
),
sales_and_returns AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND i.i_brand = 'Brand#12'
      AND sm.sm_code = 'AIR'
      AND wsite.web_country = 'United States'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, i.i_brand, i.i_category, d_sold.d_year, d_sold.d_month_seq
),
filtered_sales AS (
    SELECT s.*
    FROM sales_and_returns s
    JOIN final_items f ON s.i_item_id = f.i_item_id
)
SELECT
    i_item_id,
    i_brand,
    i_category,
    d_year,
    d_month_seq,
    total_net_profit,
    total_sales,
    total_quantity,
    total_net_loss,
    total_return_quantity,
    (total_net_profit - COALESCE(total_net_loss, 0)) AS net_profit_after_returns,
    SUM(total_net_profit - COALESCE(total_net_loss, 0)) OVER (PARTITION BY i_brand ORDER BY d_month_seq) AS cum_brand_profit,
    RANK() OVER (PARTITION BY i_brand ORDER BY (total_net_profit - COALESCE(total_net_loss, 0)) DESC) AS profit_rank
FROM filtered_sales
ORDER BY i_brand, d_month_seq DESC
LIMIT 100
