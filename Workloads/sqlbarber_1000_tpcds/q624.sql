SELECT
    fi.i_item_id,
    fi.i_brand,
    fi.i_category,
    inv.inv_quantity_on_hand,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM
    (SELECT i_item_sk, i_item_id, i_brand, i_category
     FROM item
     WHERE i_category = 'Books                                             '
    ) AS fi
JOIN catalog_sales cs
    ON fi.i_item_sk = cs.cs_item_sk
JOIN web_returns wr
    ON fi.i_item_sk = wr.wr_item_sk
JOIN inventory inv
    ON fi.i_item_sk = inv.inv_item_sk
GROUP BY
    fi.i_item_id,
    fi.i_brand,
    fi.i_category,
    inv.inv_quantity_on_hand
HAVING
    inv.inv_quantity_on_hand > 704
