WITH store_sales_ch AS (
    SELECT
        d.d_date_sk AS d_date_sk,
        d.d_date AS d_date,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount,
        st.s_state AS state,
        ss.ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN store st ON st.s_store_sk = ss.ss_store_sk
),
web_sales_ch AS (
    SELECT
        d.d_date_sk AS d_date_sk,
        d.d_date AS d_date,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        ws.ws_ext_discount_amt AS discount,
        wsite.web_state AS state,
        ws.ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
),
catalog_sales_ch AS (
    SELECT
        d.d_date_sk AS d_date_sk,
        d.d_date AS d_date,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        cc.cc_state AS state,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
),
sales_union AS (
    SELECT * FROM store_sales_ch
    UNION ALL
    SELECT * FROM web_sales_ch
    UNION ALL
    SELECT * FROM catalog_sales_ch
),
store_returns_agg AS (
    SELECT
        r.sr_returned_date_sk AS d_date_sk,
        d.d_date AS d_date,
        r.sr_item_sk AS item_sk,
        SUM(r.sr_return_quantity) AS ret_quantity,
        SUM(r.sr_return_amt_inc_tax) AS ret_amount,
        SUM(r.sr_net_loss) AS ret_loss,
        st.s_state AS state,
        'store' AS channel
    FROM store_returns r
    JOIN date_dim d ON d.d_date_sk = r.sr_returned_date_sk
    JOIN store st ON st.s_store_sk = r.sr_store_sk
    GROUP BY r.sr_returned_date_sk, d.d_date, r.sr_item_sk, st.s_state
),
catalog_returns_agg AS (
    SELECT
        r.cr_returned_date_sk AS d_date_sk,
        d.d_date AS d_date,
        r.cr_item_sk AS item_sk,
        SUM(r.cr_return_quantity) AS ret_quantity,
        SUM(r.cr_return_amt_inc_tax) AS ret_amount,
        SUM(r.cr_net_loss) AS ret_loss,
        cc.cc_state AS state,
        'catalog' AS channel
    FROM catalog_returns r
    JOIN date_dim d ON d.d_date_sk = r.cr_returned_date_sk
    JOIN call_center cc ON cc.cc_call_center_sk = r.cr_call_center_sk
    GROUP BY r.cr_returned_date_sk, d.d_date, r.cr_item_sk, cc.cc_state
),
returns_union AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
),
sales_agg AS (
    SELECT
        year(s.d_date) AS sales_year,
        month(s.d_date) AS sales_month,
        s.channel,
        s.state,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.sales_amount) AS total_sales_amount,
        SUM(s.profit) AS total_profit,
        SUM(s.discount) AS total_discount
    FROM sales_union s
    GROUP BY year(s.d_date), month(s.d_date), s.channel, s.state
),
returns_agg AS (
    SELECT
        year(r.d_date) AS sales_year,
        month(r.d_date) AS sales_month,
        r.channel,
        r.state,
        SUM(r.ret_quantity) AS total_returns_quantity,
        SUM(r.ret_amount) AS total_returns_amount,
        SUM(r.ret_loss) AS total_return_loss
    FROM returns_union r
    GROUP BY year(r.d_date), month(r.d_date), r.channel, r.state
),
combined AS (
    SELECT
        sa.sales_year,
        sa.sales_month,
        sa.channel,
        sa.state,
        sa.total_quantity_sold,
        sa.total_sales_amount,
        sa.total_profit,
        sa.total_discount,
        COALESCE(ra.total_returns_quantity, 0) AS total_returns_quantity,
        COALESCE(ra.total_returns_amount, 0) AS total_returns_amount,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        sa.total_quantity_sold - COALESCE(ra.total_returns_quantity, 0) AS net_quantity,
        sa.total_sales_amount - COALESCE(ra.total_returns_amount, 0) AS net_sales,
        sa.total_profit - COALESCE(ra.total_return_loss, 0) AS net_profit,
        CASE WHEN sa.total_quantity_sold = 0 THEN 0 ELSE sa.total_discount / sa.total_quantity_sold END AS avg_discount_per_item
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.sales_year = ra.sales_year
       AND sa.sales_month = ra.sales_month
       AND sa.channel = ra.channel
       AND sa.state = ra.state
),
promo_agg AS (
    SELECT
        year(s.d_date) AS sales_year,
        month(s.d_date) AS sales_month,
        s.channel,
        s.state,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM sales_union s
    LEFT JOIN promotion p ON p.p_promo_sk = s.promo_sk
    GROUP BY year(s.d_date), month(s.d_date), s.channel, s.state
),
inventory_agg AS (
    SELECT
        year(d.d_date) AS sales_year,
        month(d.d_date) AS sales_month,
        w.w_state AS state,
        AVG(i.inv_quantity_on_hand) AS avg_inventory
    FROM inventory i
    JOIN date_dim d ON d.d_date_sk = i.inv_date_sk
    JOIN warehouse w ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY year(d.d_date), month(d.d_date), w.w_state
),
final AS (
    SELECT
        c.sales_year,
        c.sales_month,
        c.channel,
        c.state,
        c.total_quantity_sold,
        c.total_sales_amount,
        c.total_returns_quantity,
        c.total_returns_amount,
        c.net_quantity,
        c.net_sales,
        c.net_profit,
        c.avg_discount_per_item,
        COALESCE(i.avg_inventory, 0) AS avg_inventory,
        COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
        ROW_NUMBER() OVER (PARTITION BY c.sales_year, c.sales_month, c.channel ORDER BY c.net_profit DESC) AS profit_rank
    FROM combined c
    LEFT JOIN inventory_agg i
        ON i.sales_year = c.sales_year
       AND i.sales_month = c.sales_month
       AND i.state = c.state
    LEFT JOIN promo_agg p
        ON p.sales_year = c.sales_year
       AND p.sales_month = c.sales_month
       AND p.channel = c.channel
       AND p.state = c.state
)
SELECT *
FROM final
WHERE profit_rank <= 5
  AND sales_year BETWEEN 1999 AND 2001
ORDER BY sales_year, sales_month, channel, profit_rank
